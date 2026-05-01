import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/utils/app_snackbar.dart';
import '../providers/profile_provider.dart';

class ProfileEditView extends StatefulWidget {
  const ProfileEditView({super.key});

  @override
  State<ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends State<ProfileEditView> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _bioController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationPreferencesController;

  @override
  void initState() {
    super.initState();
    final user = context.read<ProfileProvider>().user;
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _locationPreferencesController = TextEditingController(
      text: user?.locationPreferences ?? '',
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _locationPreferencesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<ProfileProvider>();
    final err = await provider.updateProfileInfo(
      fullName: _fullNameController.text,
      bio: _bioController.text,
      phoneNumber: _phoneController.text,
      locationPreferences: _locationPreferencesController.text,
    );
    if (!mounted) return;

    if (err != null) {
      showAppSnackBar(context, err, isError: true);
      return;
    }

    showAppSnackBar(context, 'Profil güncellendi.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final updating = context.select<ProfileProvider, bool>(
      (p) => p.updatingProfile,
    );

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        actions: [
          TextButton(
            onPressed: updating ? null : _save,
            child: Text(
              'Kaydet',
              style: theme.textTheme.labelLarge?.copyWith(
                color: updating
                    ? AppColors.secondary.withValues(alpha: 0.5)
                    : AppColors.primaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _FieldCard(
            child: TextField(
              controller: _fullNameController,
              enabled: !updating,
              textCapitalization: TextCapitalization.words,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                hintText: 'Ad soyad gir',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FieldCard(
            child: TextField(
              controller: _bioController,
              enabled: !updating,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Biyografi',
                hintText: 'Kendini kısaca tanıt',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FieldCard(
            child: TextField(
              controller: _phoneController,
              enabled: !updating,
              keyboardType: TextInputType.phone,
              maxLength: 20,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                hintText: 'Opsiyonel',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FieldCard(
            child: TextField(
              controller: _locationPreferencesController,
              enabled: !updating,
              maxLines: 2,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Konum Tercihleri',
                hintText: 'Örn: istanbul, ankara, doğa, tarih',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: updating ? null : _save,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
            ),
            child: updating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: child,
      ),
    );
  }
}
