import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../data/models/content_dto.dart';
import '../content/screens/content_detail_view.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/screens/login_screen.dart';
import '../content/providers/contents_provider.dart';

/// Ana sayfa: karşılama + popüler bölgeler + yakındaki içerikler (API).
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  static const _popular = [
    'Göreme Vadisi',
    'Ürgüp',
    'Avanos',
    'Uçhisar',
    'Ihlara',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentsProvider>().loadNearby(
            latitude: 38.6431,
            longitude: 34.8282,
            radiusKm: 40,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final contents = context.watch<ContentsProvider>();

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'BilDünya',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.primaryContainer,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Çıkış',
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil(
                LoginScreen.routeName,
                (route) => false,
              );
            },
            icon: const Icon(Symbols.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryContainer,
        onRefresh: () => context.read<ContentsProvider>().loadNearby(
              latitude: 38.6431,
              longitude: 34.8282,
              radiusKm: 40,
            ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Hoş Geldin Gezgin',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              auth.user?.displayName != null
                  ? '${auth.user!.displayName}, keşfe hazır mısın?'
                  : 'Kapadokya ve ötesinde yeni rotalar seni bekliyor.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.secondary.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Popüler bölgeler',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _popular.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return Chip(
                    label: Text(
                      _popular[index],
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: AppColors.surfaceContainerLow,
                    side: BorderSide(
                      color: AppColors.outlineVariant.withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Yakınındaki içerikler',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (contents.loadingNearby)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (contents.nearbyError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  contents.nearbyError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ...contents.nearby.map((c) => _NearbyTile(content: c)),
            if (!contents.loadingNearby && contents.nearby.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Henüz yakın içerik yok veya sunucuya erişilemiyor.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NearbyTile extends StatelessWidget {
  const _NearbyTile({required this.content});

  final ContentDto content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title =
        content.locationName?.trim().isNotEmpty == true
            ? content.locationName!
            : (content.description ?? 'İçerik').split('\n').first;
    final thumb = ApiConfig.resolveFileUrl(content.fileUrl);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: BorderSide(
          color: AppColors.outlineVariant.withValues(alpha: 0.12),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 56,
            height: 56,
            child: thumb.isNotEmpty
                ? Image.network(
                    thumb,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const ColoredBox(
                      color: AppColors.surfaceVariant,
                      child: Icon(Symbols.image, color: AppColors.secondary),
                    ),
                  )
                : const ColoredBox(
                    color: AppColors.surfaceVariant,
                    child: Icon(Symbols.explore, color: AppColors.secondary),
                  ),
          ),
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          content.user?.displayName ?? '',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.secondary,
          ),
        ),
        trailing: const Icon(Symbols.chevron_right, color: AppColors.secondary),
        onTap: () {
          final id = content.id;
          if (id == null) return;
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (context) => ContentDetailView(
                args: ContentDetailArgs(contentId: id, preview: content),
              ),
            ),
          );
        },
      ),
    );
  }
}
