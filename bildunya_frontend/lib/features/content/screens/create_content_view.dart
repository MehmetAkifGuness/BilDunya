import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/create_content_request.dart';
import '../models/picked_location.dart';
import '../providers/contents_provider.dart';
import '../../shell/main_shell.dart';
import 'location_picker_view.dart';

/// Paylaşım oluştur: fotoğraf/video, açıklama, konum (koyu tema).
class CreateContentView extends StatefulWidget {
  const CreateContentView({super.key});

  static const String routeName = '/content/create';

  @override
  State<CreateContentView> createState() => _CreateContentViewState();
}

class _CreateContentViewState extends State<CreateContentView> {
  static const _defaultLocation = PickedLocation(
    latitude: 38.6431,
    longitude: 34.8282,
    locationName: 'Göreme Vadisi',
  );

  final _description = TextEditingController();
  final _picker = ImagePicker();
  XFile? _mediaFile;
  String _contentType = 'IMAGE';
  PickedLocation _location = _defaultLocation;
  String _shareType = 'PUBLIC';

  @override
  void dispose() {
    _description.dispose();
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
      setState(() {
        _mediaFile = file;
        _contentType = 'IMAGE';
      });
    }
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (!mounted) return;
    if (file != null) {
      setState(() {
        _mediaFile = file;
        _contentType = 'VIDEO';
      });
    }
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute<PickedLocation>(
        fullscreenDialog: true,
        builder: (context) => const LocationPickerView(),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _location = result);
  }

  Future<void> _publish() async {
    final path = _mediaFile?.path;
    final text = _description.text.trim();
    if (path == null || path.isEmpty) {
      showAppSnackBar(context, 'Lütfen bir medya seç.', isError: true);
      return;
    }
    if (text.isEmpty) {
      showAppSnackBar(context, 'Lütfen bir açıklama yaz.', isError: true);
      return;
    }

    final contents = context.read<ContentsProvider>();
    final err = await contents.uploadContent(
      request: CreateContentRequest(
        description: text,
        contentType: _contentType,
        latitude: _location.latitude,
        longitude: _location.longitude,
        locationName: _location.locationName,
        shareType: _shareType,
      ),
      mediaPath: path,
    );
    if (!mounted) return;

    if (err != null) {
      showAppSnackBar(
        context,
        err.replaceFirst('Exception: ', ''),
        isError: true,
      );
      return;
    }

    showAppSnackBar(context, 'Paylaşımın yayında!');
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(MainShell.routeName, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uploading = context.watch<ContentsProvider>().uploadingContent;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Paylaşım oluştur',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Symbols.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Neler düşünüyorsun?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fotoğrafını veya videonu ekle, kısa bir not yaz ve konumunu seç.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.secondary.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                      child: _mediaFile == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Symbols.perm_media,
                                  size: 48,
                                  color: AppColors.secondary.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Medya seç',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            )
                          : _contentType == 'IMAGE'
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                              child: Image.file(
                                File(_mediaFile!.path),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Symbols.videocam,
                                    size: 52,
                                    color: AppColors.primaryContainer,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _mediaFile!.path
                                        .split(Platform.pathSeparator)
                                        .last,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: AppColors.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
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
                          label: const Text('Fotoğraf seç'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: uploading ? null : _pickVideo,
                          icon: const Icon(Symbols.videocam),
                          label: const Text('Video seç'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _description,
                    maxLines: 5,
                    minLines: 3,
                    textInputAction: TextInputAction.newline,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Bugün neler keşfettin?',
                      hintStyle: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurfaceHint,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        borderSide: BorderSide(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        borderSide: BorderSide(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        borderSide: BorderSide(
                          color: AppColors.primaryContainer.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Material(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    child: InkWell(
                      onTap: uploading ? null : _openLocationPicker,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Symbols.location_on,
                              color: AppColors.primaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Konum ekle',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.secondary,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _location.locationName,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: AppColors.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Symbols.chevron_right,
                              color: AppColors.secondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _shareType,
                    decoration: InputDecoration(
                      labelText: 'Paylaşım tipi',
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        borderSide: BorderSide(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        borderSide: BorderSide(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        borderSide: BorderSide(
                          color: AppColors.primaryContainer.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ),
                    dropdownColor: AppColors.surfaceContainer,
                    items: const [
                      DropdownMenuItem(value: 'PUBLIC', child: Text('İsimli')),
                      DropdownMenuItem(
                        value: 'ANONYMOUS',
                        child: Text('Anonim'),
                      ),
                    ],
                    onChanged: uploading
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _shareType = value);
                            }
                          },
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: uploading ? null : _publish,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                    ),
                    child: Text(
                      'Yayınla',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (uploading)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.55),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppColors.primaryContainer,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Yükleniyor…',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
